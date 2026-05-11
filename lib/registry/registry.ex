defmodule DockerDigests.Registry do
  @moduledoc """
  The `DockerDigests.Registry` module parses images and interacts with the
  docker registry v2 API to pull information about images.
  """
  require Logger

  defmodule Image do
    defstruct [:registry, :namespace, :name, :tag]
  end

  @doc """
  `fetch_manifest` takes an Image struct and returns the image manifest.
  The image digest is pulled exclusively from a docker registry v2 API.
  If the image doesn't contain a registry, the function will return an error.
  """
  def image_digest(img, skip_tls_verify, insecure, auth) do
    image = image_info(img)

    case image do
      {:ok, %Image{registry: nil}} ->
        {:error, "image doesn't contain registry, can't fetch digest"}

      {:ok, %Image{name: nil}} ->
        {:error, "image doesn't contain a name, can't fetch digest"}

      {:ok, %Image{namespace: nil}} ->
        {:error, "image doesn't contain a namespace, can't fetch digest"}

      {:ok, %Image{tag: nil}} ->
        {:error, "image doesn't contain a tag, can't fetch digest"}

      {:ok, img} ->
        fetch_manifest(img, skip_tls_verify, insecure, auth)

      {:error, reason} ->
        {:error, "failed to parse image: " <> reason}
    end
  end

  defp fetch_manifest(img, skip_tls_verify, insecure, auth) do
    Logger.debug("fetching manifest")

    req =
      if skip_tls_verify,
        do: Req.new(connect_options: [transport_opts: [verify: :verify_none]]),
        else: Req.new()

    req =
      if auth != nil,
        do: Req.Request.put_header(req, "authorization", "Bearer " <> auth),
        else: req

    Logger.debug(inspect(req))

    protocol = if insecure, do: "http://", else: "https://"

    case Req.get(
           req,
           url:
             protocol <>
               img.registry <>
               "/v2/" <> img.namespace <> "/" <> img.name <> "/manifests/" <> img.tag
           # TODO: add accept headers
         ) do
      {:ok, %Req.Response{status: 401, headers: headers}} ->
        Logger.debug(
          "received 401 response, trying to authenticate using www-authenticate header information"
        )

        {:ok, token} = fetch_repo_auth(req, headers)

        fetch_manifest(img, skip_tls_verify, insecure, token)

      {:ok, %Req.Response{status: 200, headers: headers}} ->
        {:ok, headers["docker-content-digest"] |> List.first()}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def fetch_repo_auth(req, headers) do
    auth_bearer =
      with "Bearer " <> rest <- List.first(headers["www-authenticate"], nil) do
        rest
      else
        nil ->
          raise("failed to authenticate, expected 'www-authenticate' header")

        value ->
          raise(
            "unexpected value, expected header www-authenticate to start with 'Bearer ': #{inspect(value)}"
          )
      end

    {:ok, opts} = parse_auth_opts(auth_bearer)
    Logger.debug(opts)

    case Req.get(req,
           url: opts["realm"],
           params: [scope: opts["scope"], service: opts["service"]]
         ) do
      {:ok, %Req.Response{status: 200, body: %{"token" => token}}} ->
        Logger.debug(token)
        {:ok, token}

      {:error, reason} ->
        {:error, {:auth_request_error, reason}}

      _ ->
        raise("failed to fetch auth")
    end
  end

  def parse_auth_opts(auth_opts) do
    auth_opts
    |> String.split(",")
    |> Enum.reduce_while(%{}, fn pair, acc ->
      case String.split(pair, "=", parts: 2) do
        [key, value] ->
          value = value |> String.trim(~s(")) |> String.replace(" ", "+")
          {:cont, Map.put(acc, key, value)}

        _ ->
          {:halt, {:error, "match error when spliting auth header"}}
      end
    end)
    |> case do
      {:error, _} = err -> err
      map -> {:ok, map}
    end
  end

  @doc """
  `image_info` receives a full image with registry and
  separates it into four components, `registry`, `namespace`, `image` and `tag`.
  If any components are missing, the result will be nil.
  """
  def image_info(image) do
    with {:ok, {registry, namespace, name_tag}} <-
           image
           |> remove_http_prefix()
           |> String.split("/", trim: true)
           |> extract_registry_namespace_name_tag(),
         {:ok, {image_name, tag}} <- extract_name_tag(String.split(name_tag, ":")) do
      {:ok, %Image{registry: registry, namespace: namespace, name: image_name, tag: tag}}
    end
  end

  def extract_registry_namespace_name_tag([reg, namespace, name_tag]) do
    {:ok, {reg, namespace, name_tag}}
  end

  def extract_registry_namespace_name_tag([reg_or_namespace, name_tag]) do
    {reg, namespace} = registry_or_namespace(reg_or_namespace)
    {:ok, {reg, namespace, name_tag}}
  end

  def extract_name_tag([name, tag]) do
    {:ok, {name, tag}}
  end

  def extract_name_tag([_image]) do
    {:error, "image missing the tag"}
  end

  def registry_or_namespace(reg_or_namespace) do
    case String.contains?(reg_or_namespace, ".") do
      true ->
        {reg_or_namespace, nil}

      false ->
        {nil, reg_or_namespace}
    end
  end

  def remove_http_prefix("https://" <> rest), do: rest
  def remove_http_prefix("http://" <> rest), do: rest
  def remove_http_prefix(rest), do: rest
end

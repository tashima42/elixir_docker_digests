defmodule DockerDigests.Registry do
  @moduledoc """
  The `DockerDigests.Registry` module parses images and interacts with the
  docker registry v2 API to pull information about images.
  """

  defmodule Image do
    defstruct [:registry, :namespace, :image, :tag]
  end

  @doc """
  `fetch_manifest` takes an Image struct and returns the image manifest.
  The image digest is pulled exclusively from a docker registry v2 API. 
  If the image doesn't contain a registry, the function will return an error.
  """
  def image_digest(image) do
    case image do
      %Image{registry: nil} ->
        {:error, "image doesn't contain registry, can't fetch digest"}

      %Image{registry: registry, namespace: namespace, image: img, tag: tag} ->
        case Req.get(
               "http://" <> registry <> "/v2/" <> namespace <> "/" <> img <> "/manifests/" <> tag
             ) do
          {:ok, res} ->
            {:ok, Req.Response.get_header(res, "Docker-Content-Digest") |> List.first()}
        end

      _ ->
        {:error, "empty image, provide an image with a registry to fetch the digest"}
    end
  end

  @doc """
  `image_info` receives a full image with registry and
  separates it into four components, `registry`, `namespace`, `image` and `tag`.
  If any components are missing, the result will be nil.
  """
  def image_info(image) do
    with {:ok, {registry, namespace, image}} <-
           image
           |> remove_http_prefix()
           |> String.split("/", trim: true)
           |> extract_registry_namespace_image(),
         {:ok, {final_image, tag}} <- extract_image_tag(String.split(image, ":")) do
      {:ok, %Image{registry: registry, namespace: namespace, image: final_image, tag: tag}}
    end
  end

  def extract_registry_namespace_image([reg, namespace, image]) do
    {:ok, {reg, namespace, image}}
  end

  def extract_registry_namespace_image([reg_or_namespace, image]) do
    {reg, namespace} = registry_or_namespace(reg_or_namespace)
    {:ok, {reg, namespace, image}}
  end

  def extract_image_tag([image, tag]) do
    {:ok, {image, tag}}
  end

  def extract_image_tag([_image]) do
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

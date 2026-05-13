defmodule DockerDigests do
  @moduledoc """
  Docker Digests is a CLI utility to get the digests of docker image manifests.

  This tool connects to a docker registry v2 API and finds the digest for each image without
  pulling the whole image, but using the digest header returned when fetching the manifest.
  """
  require Logger

  def main(argv) do
    optimus =
      Optimus.new!(
        name: "elixir_docker_digests",
        description: "Docker image digests fetcher",
        version: "0.0.1",
        author: "opensource@tashimalab.uk",
        about: "Lightweight tool to fetch docker image digests",
        allow_unknown_args: false,
        parse_double_dash: true,
        flags: [
          verbosity: [
            short: "-v",
            long: "--verbose",
            help: "Verbosity level",
            multiple: false,
            global: true
          ],
          skip_tls_verify: [
            short: "-t",
            long: "--skip-tls-verify",
            help: "Skip TLS verification on HTTP requests",
            multiple: false,
            global: true
          ],
          insecure: [
            short: "-k",
            long: "--insecure",
            help: "Don't use https for requests",
            multiple: false,
            global: true
          ]
        ],
        options: [
          images: [
            value_name: "IMAGE",
            short: "-i",
            long: "--image",
            help: "Image to fetch the digest from (accepts multiple)",
            multiple: true,
            required: true
          ],
          auth: [
            value_name: "AUTH",
            short: "-a",
            long: "--auth",
            help: "Auth token",
            multiple: false,
            required: false
          ]
        ]
      )

    args = Optimus.parse!(optimus, argv)

    configure_logger(args.flags.verbosity)

    images = args.options.images

    Logger.debug("fetching images: " <> Enum.join(images, ","))

    digests_results =
      DockerDigests.Registry.images_digest(
        images,
        args.flags.skip_tls_verify,
        args.flags.insecure,
        args.options.auth
      )

    Enum.each(digests_results, fn result ->
      case result do
        {:ok, {img, digest}} -> IO.puts("#{img}@#{digest}")
        {:error, {img, reason}} -> IO.puts("Failed to get image digest: #{img}: #{reason}")
      end
    end)

    # Enum.each(images, fn img ->
    #   Logger.debug("trying to fetch digest for image: " <> img)
    #
    #   case DockerDigests.Registry.image_digest(
    #          img,
    #          args.flags.skip_tls_verify,
    #          args.flags.insecure,
    #          args.options.auth
    #        ) do
    #     {:ok, digest} -> IO.puts(img <> "@" <> digest)
    #     {:error, reason} -> raise(reason)
    #   end
    # end)
  end

  def configure_logger(verbose) do
    case verbose do
      true -> Logger.configure(level: :debug)
      _ -> Logger.configure(level: :info)
    end
  end
end

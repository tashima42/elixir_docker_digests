defmodule DockerDigests do
  @moduledoc """
  Docker Digests is a CLI utility to get the digests of docker image manifests.

  This tool connects to a docker registry v2 API and finds the digest for each image without
  pulling the whole image, but using the digest header returned when fetching the manifest.
  """

  def main(argv) do
    optimus =
      Optimus.new!(
        name: "docker-digests",
        description: "Docker image digests fetcher",
        version: "0.0.1",
        author: "opensource@tashimalab.uk",
        about: "Lightweight tool to fetch docker image digests",
        allow_unknown_args: false,
        parse_double_dash: true,
        flags: [
          verbosity: [
            short: "-v",
            help: "Verbosity level",
            multiple: true,
            global: true
          ]
        ],
        options: [
          images: [
            value_name: "IMAGE",
            short: "-i",
            long: "--image",
            help: "image to fetch the digest from (accepts multiple)",
            multiple: true,
            required: true
          ]
        ]
      )

    args = Optimus.parse!(optimus, argv)

    Enum.each(args.options.images, fn img ->
      {:ok, image} = DockerDigests.Registry.image_info(img)
      {:ok, digest} = DockerDigests.Registry.image_digest(image)
      IO.puts(digest)
    end)
  end
end

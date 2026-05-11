defmodule DockerDigestsTest do
  use ExUnit.Case
  doctest DockerDigests

  test "image info with registry, namespace and tag" do
    {:ok, image} = DockerDigests.Registry.image_info("registry.local/hello/world:v1.0")

    assert image.registry == "registry.local"
    assert image.namespace == "hello"
    assert image.name == "world"
    assert image.tag == "v1.0"
  end

  test "image with full registry address, namespace and tag" do
    {:ok, image} = DockerDigests.Registry.image_info("https://registry.local/hello/world:v1.0")

    assert image.registry == "registry.local"
    assert image.namespace == "hello"
    assert image.name == "world"
    assert image.tag == "v1.0"
  end

  test "image info without registry, with namespace and tag" do
    {:ok, image} = DockerDigests.Registry.image_info("hello/world:v1.0")

    assert image.registry == nil
    assert image.namespace == "hello"
    assert image.name == "world"
    assert image.tag == "v1.0"
  end

  test "image info with registry, without namespace" do
    {:ok, image} = DockerDigests.Registry.image_info("registry.local/world:v1.0")

    assert image.registry == "registry.local"
    assert image.namespace == nil
    assert image.name == "world"
    assert image.tag == "v1.0"
  end

  test "image info with registry, namespace, image and without tag" do
    case DockerDigests.Registry.image_info("registry.local/hello/world") do
      {:ok, image} ->
        assert image.registry == "registry.local"
        assert image.namespace == "hello"
        assert image.name == "world"
        assert image.tag == nil

      {:error, reason} ->
        assert reason == "image missing the tag"
    end
  end

  test "image info with registry and port" do
    {:ok, image} = DockerDigests.Registry.image_info("http://127.0.0.1:5000/hello/world:v1.0")

    assert image.registry == "127.0.0.1:5000"
    assert image.namespace == "hello"
    assert image.name == "world"
    assert image.tag == "v1.0"
  end

  test "image info with registry and port without http prefix" do
    {:ok, image} = DockerDigests.Registry.image_info("127.0.0.1:5000/hello/world:v1.0")

    assert image.registry == "127.0.0.1:5000"
    assert image.namespace == "hello"
    assert image.name == "world"
    assert image.tag == "v1.0"
  end

  # test "fetch digest with image missing registry" do
  #   {:ok, image} = DockerDigests.Registry.image_info("hello/world:v1.0")
  #   {:error, reason} = DockerDigests.Registry.image_digest(image)
  #   assert reason == "image doesn't contain registry, can't fetch digest"
  # end
  #
  # test "fetch digest with empty image" do
  #   {:error, reason} = DockerDigests.Registry.image_digest(nil)
  #   assert reason == "empty image, provide an image with a registry to fetch the digest"
  # end
  #
  # test "fetch digest" do
  #   {:ok, image} = DockerDigests.Registry.image_info("127.0.0.1:5001/podman/hello:latest")
  #   {:ok, digest} = DockerDigests.Registry.image_digest(image)
  #   assert digest == "sha256:da76e78b2dc461a87c4489cd3e5e3beb1e3f3e781a51228a9a1b5671a4b30091"
  # end
end

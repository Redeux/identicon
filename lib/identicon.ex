defmodule Identicon do
  @moduledoc """
  Documentation for Identicon.
  """

  @doc """ 
    Used to run the workflow for converting a string into an image
  """
  def main(input) do
    input 
    |> compute_md5
    |> pick_color
    |> build_grid
    |> filter_odd_squares
    |> build_pixel_map
    |> draw_image
    |> save_image(input)
  end

  def save_image(image, filename) do
    File.write('#{filename}.png', image)  
  end
  
  def draw_image(%Identicon.Image{rgb: rgb, pixel_map: pixel_map}) do
    image = :egd.create(250, 250)
    fill = :egd.color(rgb)

    Enum.each pixel_map, fn({first, last}) ->
      :egd.filledRectangle(image, first, last, fill)
    end

    :egd.render(image)
  end

  def build_pixel_map(%Identicon.Image{grid: grid} = image) do
    pixel_map = Enum.map grid, fn({_code, index}) -> 
      horizontal = rem(index, 5) * 50
      verticle = div(index, 5) * 50

      top_left = {horizontal, verticle}
      bottom_right = {horizontal + 50, verticle + 50}

      {top_left, bottom_right}
    end

    %Identicon.Image{image | pixel_map: pixel_map}
  end

  def build_grid(%Identicon.Image{hex: hex} = image) do
    grid =
      hex 
      |> Enum.chunk(3)
      |> Enum.map(&mirror_row/1)
      |> List.flatten
      |> Enum.with_index

    %Identicon.Image{image | grid: grid}
  end

  def filter_odd_squares(%Identicon.Image{grid: grid} = image) do
    grid = Enum.filter grid, fn({square, _index}) -> 
      rem(square, 2) == 0
    end

    %Identicon.Image{image | grid: grid}
  end

  def mirror_row([first, second | _tail] = row) do
    row ++ [second, first]
  end

  def pick_color(%Identicon.Image{hex: [r, g, b | _tail]} = image) do
    %Identicon.Image{image | rgb: {r, g, b}}
  end

  @doc """ 
    Computes the MD5 hash of a string
  """
  def compute_md5(input) do
    hex = :crypto.hash(:md5, input)
    |> :binary.bin_to_list

    %Identicon.Image{hex: hex}
  end
end

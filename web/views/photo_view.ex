defmodule Photoshare.PhotoView do
  use Photoshare.Web, :view

  def split_items(items, count) do
    halfway = round(Enum.count(items) / 2)
    {a,b} = Enum.split(items, halfway)
    if (count == 1), do: a, else: b
  end

  def increment_page(page) do
    page |> Kernel.+(1) |> Integer.to_string
  end
end

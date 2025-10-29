defmodule Onion.Utils do
  @moduledoc """
  Генератор UUID v4 без внешних зависимостей.
  """

  use Bitwise

  @doc """
  Возвращает новый UUID v4 в виде строки "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".
  """
  def uuid4 do
    <<b1, b2, b3, b4,
      b5, b6, b7, b8,
      b9, b10, b11, b12,
      b13, b14, b15, b16>> = :crypto.strong_rand_bytes(16)

    b7_ver = bor(band(b7, 0x0F), 0x40)
    b9_var = bor(band(b9, 0x3F), 0x80)

    hex1  = byte_hex(b1)  <> byte_hex(b2)  <> byte_hex(b3)  <> byte_hex(b4)
    hex2  = byte_hex(b5)  <> byte_hex(b6)
    hex3  = byte_hex(b7_ver) <> byte_hex(b8)
    hex4  = byte_hex(b9_var) <> byte_hex(b10)
    hex5  = byte_hex(b11) <> byte_hex(b12) <> byte_hex(b13) <>
            byte_hex(b14) <> byte_hex(b15) <> byte_hex(b16)

    hex1 <> "-" <> hex2 <> "-" <> hex3 <> "-" <> hex4 <> "-" <> hex5
  end

  defp byte_hex(byte) when is_integer(byte) and byte >= 0 and byte < 256 do
    :io_lib.format("~2.16.0b", [byte]) |> IO.iodata_to_binary()
  end
end
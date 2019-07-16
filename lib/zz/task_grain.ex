defmodule Zz.TaskGrain do
  alias Zz.Grains.Grain, as: G
  alias Zz.Repo

  def a(dqqq \\ 1023) do
    u = "http://59.55.120.113:8311/web/bidPriceSpecialWatch?specialNo=#{dqqq}&specialName=z"
    uu = "http://59.55.120.113:8311/trade/open/watchSpecial"
    headers = [referer: u]
    options = [params: [specialNo: dqqq]]
    {o, url} = HTTPoison.post(uu, "", headers, options)

    if o == :ok do
      url.body |> Jason.decode!()
    else
      a(dqqq)
    end
  end

  def grain(y, pid) do
    dd = a(y)

    case dd["status"] do
      "yes" ->
        Enum.each(dd["rows"], fn jj ->
          if !String.match?(jj["varietyName"], ~r/玉米|麦|油|豆/) do
            j(jj, dd, pid)
          end
        end)

        grain(y, pid)

      "end" ->
        rows = Agent.get(pid, & &1)

        if !Enum.empty?(rows) do
          Enum.each(rows, fn attr ->
            changeset = G.changeset(%G{}, attr)
            Repo.insert(changeset)
            Agent.update(pid, &Enum.drop_every(&1, 1))
          end)
        end

      _ ->
        Process.sleep(7000)
        grain(y, pid)
    end
  end

  def j(j, d, pid) do
    case String.to_integer(j["remainSeconds"]) do
      x when x > 2 ->
        rows = Agent.get(pid, & &1)

        if !Enum.empty?(rows) do
          Enum.each(rows, fn attr ->
            changeset = G.changeset(%G{}, attr)
            Repo.insert(changeset)
            Agent.update(pid, &Enum.drop_every(&1, 1))
          end)
        end

        Process.sleep(x * 1000 - 2000)
        grain(d["specialNo"], pid)

      x when x <= 2 ->
        s(j, d["specialName"], pid)
    end
  end

  def s(d, dd, pid) do
    x = d["requestAlias"]

    trantype =
      if Regex.match?(~r/采购/, dd) do
        "采购"
      else
        "拍卖"
      end

    y =
      if String.length(x) <= 12 || String.length(x) == 13 || String.length(x) == 15 do
        y = ~r/^\d+/ |> Regex.run(x)

        if y == nil do
          "00"
        else
          y |> List.to_string()
        end
      else
        # x |> String.slice(11, 2)
        "00"
      end

    status_name =
      if d["currentPrice"] == "0" do
        "流拍"
      else
        "成交"
      end

    attr = %{
      market_name: "guojia",
      mark_number: d["requestAlias"],
      year: y,
      variety: d["varietyName"],
      grade: d["gradeName"],
      trade_amount: d["num"],
      starting_price: d["basePrice"],
      latest_price: d["currentPrice"],
      address: d["requestBuyDepotName"],
      status: status_name,
      trantype: trantype
    }

    rows = Agent.get(pid, & &1)

    if Enum.empty?(rows) do
      Agent.update(pid, &[attr | &1])
    else
      if Enum.find_value(rows, false, &(&1.mark_number == attr.mark_number)) do
        if d["remainSeconds"] == "0" do
          Agent.update(pid, fn rows ->
            index = Enum.find_index(rows, &(&1.mark_number == attr.mark_number))
            List.update_at(rows, index, &Map.put(&1, :latest_price, attr.latest_price))
          end)
        end
      else
        Agent.update(pid, &[attr | &1])
      end
    end
  end
end

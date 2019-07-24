defmodule Zz.TaskGrain do
  alias Zz.Grains.Grain, as: G
  alias Zz.Repo

  def a(dqqq) do
    u = "http://59.55.120.113:8311/web/bidPriceSpecialWatch?specialNo=#{dqqq}&specialName=z"

    uu = "http://59.55.120.113:8311/trade/biddingAbout/tradeRequestListWatch"
    uuu = "http://59.55.120.113:8311/trade/biddingAbout/tradeRequestListTotalWatch"
    headers = [referer: u]
    options = [params: [specialNo: dqqq]]
    {:ok, url} = HTTPoison.post(uuu, "", headers, options)
    page_no = ceil(Jason.decode!(url.body)["total"] / 10)

    for i <- 1..page_no do
      options = [params: [specialNo: dqqq, pageNo: i, pageSize: 10]]
      {o, url} = HTTPoison.post(uu, "", headers, options)

      if o == :ok do
        url.body |> Jason.decode!()
      else
        a(dqqq)
      end
    end
  end

  def grain(y, yy) do
    dd = a(y)

    Enum.each(dd, fn dd ->
      trantype =
        if yy == "S" do
          "拍卖"
        else
          "采购"
        end

      Enum.each(dd["row"], fn d ->
        latest_price =
          if d["statusName"] == "流拍" || d["statusName"] == "等待交易" do
            "0"
          else
            Float.to_string(d["matchPrice"])
          end

        attr = %{
          market_name: "guojia",
          mark_number: d["REQUESTALIAS"],
          year: "0",
          variety: d["VARIETYNAME"],
          grade: d["GRADENAME"],
          trade_amount: Float.to_string(d["NUM"]),
          starting_price: Float.to_string(d["PRICE"]),
          latest_price: latest_price,
          address: d["BUYDEPOTNAME"],
          status: d["statusName"],
          trantype: trantype
        }

        changeset = G.changeset(%G{}, attr)
        Repo.insert(changeset)
      end)
    end)
  end
end

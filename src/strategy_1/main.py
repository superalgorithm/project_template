import asyncio
from sma_sample_strategy import SMAStrategy
from superalgorithm.exchange import CCXTExchange
from superalgorithm.data.providers.ccxt import CCXTDataSource
from superalgorithm.utils.config import config


async def main():

    datasource = CCXTDataSource("BTC/USDT", "5m", exchange_id="binance")
    strategy = SMAStrategy(
        [datasource],
        CCXTExchange(exchange_id="binance", config={"apiKey": "", "secret": ""}),
    )

    await strategy.start()


if __name__ == "__main__":
    asyncio.run(main())

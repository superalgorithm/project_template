import asyncio
from sma_sample_strategy import SMAStrategy
from superalgorithm.exchange import PaperExchange
from superalgorithm.data.providers.csv import CSVDataSource
from superalgorithm.backtesting import session_stats, upload_backtest
from superalgorithm.utils.config import config


async def backtest_complete_handler(strategy: SMAStrategy):
    print(session_stats(strategy.exchange.list_trades()))
    await upload_backtest()


async def main():

    # sample code, replace with your own code:
    csv = CSVDataSource("BTC/USDT", "5m", csv_data_folder=config.get("CSV_DATA_FOLDER"))
    strategy = SMAStrategy([csv], PaperExchange())

    strategy.on("backtest_done", backtest_complete_handler)

    await strategy.start()


if __name__ == "__main__":
    asyncio.run(main())

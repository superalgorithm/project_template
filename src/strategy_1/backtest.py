from common.helper import common_hello
import asyncio


async def main():

    # sample code, replace with your own code:

    common_hello()
    print(f"running a backtest")

    await asyncio.sleep(3)


if __name__ == "__main__":
    asyncio.run(main())

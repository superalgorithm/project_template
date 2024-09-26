import asyncio
from common.helper import common_hello


async def main():

    # sample code, replace with your own code:
    called = 0
    while True:
        called = called + 1
        print(f"strategy is running - {called}")
        common_hello()
        await asyncio.sleep(3)


if __name__ == "__main__":
    asyncio.run(main())

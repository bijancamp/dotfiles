"""
Source code: https://github.com/glzr-io/glazewm/discussions/66#discussioncomment-10838322
"""

import asyncio
import websockets
import json



async def get_status(web_socket):
    json_response = json.loads(await web_socket.recv())
    print(json_response)
    return json_response["success"]



async def main():
    uri = "ws://localhost:6123"

    async with websockets.connect(uri) as websocket:
        await websocket.send("sub -e focus_changed")

        while True:
            response = await websocket.recv()
            json_response = json.loads(response)

            if not json_response["data"]:
                continue

            try:
                containerData = json_response["data"]["focusedContainer"]
                w, h = containerData["width"], containerData["height"]

                await websocket.send("query tiling-direction")
                tilingDirection = json.loads(await websocket.recv())["data"]["tilingDirection"]

                if w < h:
                    await websocket.send('command set-tiling-direction vertical')
                    if not await get_status(websocket):
                        await websocket.send('command set-tiling direction vertical')
                        if not await get_status(websocket) and tilingDirection == "horizontal":
                            await websocket.send('command toggle-tiling-direction')
                            get_status(websocket)
                elif w > h:
                    await websocket.send('command set-tiling-direction horizontal')
                    if not await get_status(websocket):
                        await websocket.send('command set-tiling direction horizontal')
                        if not await get_status(websocket) and tilingDirection == "vertical":
                            await websocket.send('command toggle-tiling-direction')
                            get_status(websocket)
            except Exception as e:
                print(f"Error: {e}")


if __name__ == "__main__":
    asyncio.run(main())

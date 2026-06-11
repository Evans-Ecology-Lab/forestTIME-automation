import requests
from pathlib import Path
import os
ACCESS_TOKEN=os.environ["ZENODO_TOKEN"]

# try to list out the existing r

headers = {"Authorization":f"Bearer {ACCESS_TOKEN}"}

r= requests.get("https://zenodo.org/api/deposit/depositions",params={"status":"draft"},headers=headers)
print(r.json())

# go through list and remove any  drafts
resultj = r.json()

for res in resultj:
  print("removing",res)
  draft_id = res["id"]
  r= requests.delete(f"https://zenodo.org/api/deposit/depositions/{draft_id}",headers=headers)
  print()

headers = {"Authorization":f"Bearer {ACCESS_TOKEN}"}

r= requests.post("https://zenodo.org/api/deposit/depositions",json={},headers=headers)



bucket_url = r.json()["links"]["bucket"]

contents = sorted(Path("fia/parquet/").iterdir())

for content in contents:
  fname = content.name
  parent = content.parent
  headers=  {"Authorization":f"Bearer {ACCESS_TOKEN}"}

  with open(content,"rb") as fp:
    r = requests.put("%s/%s" %(bucket_url,fname), data=fp,headers=headers)
  print(r.json())

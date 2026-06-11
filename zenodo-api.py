import requests
from pathlib import Path
import os
import datetime
import json
ACCESS_TOKEN=os.environ["ZENODO_TOKEN"]

# try to list out the existing r


headers = {"Authorization":f"Bearer {ACCESS_TOKEN}"}

r= requests.get("https://zenodo.org/api/deposit/depositions",params={"status":"draft"},headers=headers)
print(r.json())

# go through list and remove any  drafts, new versions or otherwise
resultj = r.json()

for res in resultj:
  print("removing",res)
  draft_id = res["id"]
  r= requests.delete(f"https://zenodo.org/api/deposit/depositions/{draft_id}",headers=headers)
  print()


# get the latest version
gid = "20635476"
r = requests.get(f"https://zenodo.org/api/deposit/depositions/{gid}",headers=headers)
# 401
res = r.json()
res["links"]["latest"]
r = requests.get( res["links"]["latest_draft"] ,headers=headers)
res = r.json()
print(res)
print(res["id"])
latest_id = res["id"]

# make a new version


headers = {
    "Content-Type": "application/json",
    "Authorization": f"Bearer {ACCESS_TOKEN}"
}
print(latest_id)
r = requests.post(f'https://zenodo.org/api/deposit/depositions/{latest_id}/actions/newversion',
                   headers=headers)

# update the metadata

new_version_res = r.json()
print(new_version_res)
meta = new_version_res["metadata"]
x = datetime.datetime.now()
meta["publication_date"]= x.strftime("%Y-%m-%d")
meta["version"] = meta["publication_date"] 

headers = {
    "Content-Type": "application/json",
    "Authorization": f"Bearer {ACCESS_TOKEN}"
}
print(f'https://zenodo.org/api/deposit/depositions/{new_version_res["id"]}')
r = requests.put(f'https://zenodo.org/api/deposit/depositions/{new_version_res["id"]}',
                   data=json.dumps({"metadata":meta}),
                   headers=headers)




# delete the files in the new version draft

r = requests.get(f'https://zenodo.org/api/deposit/depositions/{new_version_res["id"]}/files',headers=headers)
for f in r.json():
    r = requests.delete(f'https://zenodo.org/api/deposit/depositions/{new_version_res["id"]}/files/{f["id"]}',headers=headers)
r = requests.get(f'https://zenodo.org/api/deposit/depositions/{new_version_res["id"]}',headers=headers)
new_bucket_url = r.json()["links"]["bucket"]
''' 
The target URL is a combination of the bucket link with the desired filename
seperated by a slash.
'''
files = sorted(Path("fia/parquet/").iterdir())
for f in files:
    with open(f, "rb") as fp:
        r = requests.put(
            "%s/%s" % (new_bucket_url,f.name),
            data=fp,
            headers=headers,
        )
r.json()

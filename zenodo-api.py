import requests
from pathlib import Path
import os
import datetime
import json
import time
import shutil as sh
import subprocess as sp
# make new folders that hold the 4 parquet files that are available
parquets = sorted(Path("fia/parquet").glob("*.parquet"))

# make the folders
for p in parquets:
  # the first part of the name separated by underscores is the state part

  state_name = p.name.split("_")[0]
  folder = Path(f"fia/parquet/{state_name}")
  folder.mkdir(exist_ok=True)
  # try to move the file into that folder
  sh.move(p,f"{folder}/{p.name}")
  print("moved",p)

new_locations = sorted(Path("fia/parquet").glob("*/*.parquet"))
print(new_locations)

# now run a system command to zip up the contents of the state folders
folders = sorted(Path("fia/parquet").glob("*"))

for folder in folders:
  sp.run(f"zip -r fia/parquet/{folder.name}.zip {folder}",shell=True)
  print("folder zipped",folder)




ACCESS_TOKEN=os.environ["ZENODO_TOKEN"]

# try to list out the existing r

conceptid = "17088642"
headers = {"Authorization":f"Bearer {ACCESS_TOKEN}"}

r= requests.get("https://zenodo.org/api/deposit/depositions",params={"status":"draft","q":conceptid},headers=headers)
print(r.json())

# go through list and remove any  drafts, new versions or otherwise
resultj = r.json()

for res in resultj:
  print("removing",res)
  draft_id = res["id"]
  r= requests.delete(f"https://zenodo.org/api/deposit/depositions/{draft_id}",headers=headers)
  print()


# get the latest version
#gid = "20635476"
gid = "17088643"
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

print("updating metadata")
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

print("trying to delete contents of previous version")
r = requests.get(f'https://zenodo.org/api/deposit/depositions/{new_version_res["id"]}/files',headers=headers)
for f in r.json():
    try:
      r = requests.delete(f'https://zenodo.org/api/deposit/depositions/{new_version_res["id"]}/files/{f["id"]}',headers=headers)

    except Exception as e:
      print("ran into ")
      print(e)
      print()
      print("continuing")

# adding new contents
print("adding new contents")
r = requests.get(f'https://zenodo.org/api/deposit/depositions/{new_version_res["id"]}',headers=headers)
print(r)
new_bucket_url = r.json()["links"]["bucket"]
''' 
The target URL is a combination of the bucket link with the desired filename
seperated by a slash.
'''
files = sorted(Path("fia/parquet/").glob("*.zip"))
print(files)
headers = {
    "Content-Type": "application/octet-stream",
    "Authorization": f"Bearer {ACCESS_TOKEN}"
}
for f in files:
  print("starting",f)
  with open(f, "rb") as fp:
    try:
      r = requests.put(
          "%s/%s" % (new_bucket_url,f.name),
          data=fp,
          headers=headers,
      )
      print(r)
      print(r.json())
    except Exception as e:
      print("upload snag")
      print(e)
      print("retrying after delay")
      failed = True
      retries = 5
      while failed:
        retries -=1
        if retries <0:
          print("failed completely",f)
          break
        time.sleep(2)
        try:
          r = requests.put(
              "%s/%s" % (new_bucket_url,f.name),
              data=fp,
              headers=headers,
          )
          print(r)
          failed = False
        except:
          print("failed upload again",f)

          

    print("uploaded ",f)
r.json()

headers = {'Authorization': f'Bearer {ACCESS_TOKEN}'}
r = requests.post('https://zenodo.org/api/deposit/depositions/%s/actions/publish' % new_version_res["id"],
                      headers=headers)
r.status_code
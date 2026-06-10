import requests
import os
ACCESS_TOKEN=os.environ["ZENODO_TOKEN"]

headers = {"Content-Type":"application/json","Authorization":f"Bearer {ACCESS_TOKEN}"}

r= requests.post("https://zenodo.org/api/deposit/depositions",json={},headers=headers)

bucket_url = r.json()["links"]["bucket"]

filename = "GA.zip"

path= "./fia/parquet%s" % filename

headers=  {"Authorization":"Bearer {ACCESS_TOKEN}"}

with open(path,"rb") as fp:
  r = requests.put("%s/%s" %(bucket_url,filename), data=fp,headers=headers)
print(r.json())

"""Generate isolated released-schema fixtures and compare them after APK update."""
import base64,json,re,sqlite3,sys
from pathlib import Path
NAMES={'main':'saddam_rigging_master.db','pro':'rigging_pro.db','pro2':'rigging_pro2.db'}
PHOTO=base64.b64decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=')
def create(directory):
 directory=Path(directory);directory.mkdir(parents=True,exist_ok=True)
 text=Path('test/backup_preservation_test.dart').read_text()
 for schema,name in NAMES.items():
  match=re.search(r"'"+schema+r"': \[(.*?)\n  \],",text,re.S)
  if not match:raise ValueError('Frozen released schema missing: '+schema)
  statements=re.findall(r"'''(.*?)'''",match.group(1),re.S)
  connection=sqlite3.connect(directory/name)
  connection.execute('PRAGMA user_version=1')
  for sql in statements:
   connection.execute(sql)
   table=re.search(r'CREATE TABLE (\w+)',sql).group(1)
   row={}
   for _,column,kind,*_ in connection.execute(f'PRAGMA table_info("{table}")'):
    if kind=='INTEGER':value=42
    elif kind=='REAL':value=2.5
    elif kind=='BLOB':value=PHOTO
    else:value='FIXTURE-'+column
    if column in ['expiry','inspectionDate','expiryDate','date','dt','createdAt']:value='2099-01-01'
    if column in ['equipmentId','item']:value='UPGRADE-TEST-ASSET-42'
    if column=='status':value='Active'
    if column=='result':value='HOLD'
    if column in ['detailsJson','inputJson','resultJson']:value='{"fixture":true}'
    if table=='photos' and column=='id':value=97
    row[column]=value
   columns=','.join(f'"{c}"' for c in row)
   connection.execute(f'INSERT INTO "{table}" ({columns}) VALUES ({",".join("?" for _ in row)})',list(row.values()))
  connection.commit();connection.close()
 print('Created three isolated version-1 database fixtures.')
def compare(before,after):
 count=0
 for name in NAMES.values():
  old=sqlite3.connect(Path(before)/name);new=sqlite3.connect(Path(after)/name)
  tables=[r[0] for r in old.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")]
  for table in tables:
   expected=old.execute(f'SELECT * FROM "{table}" ORDER BY 1').fetchall()
   actual=new.execute(f'SELECT * FROM "{table}" ORDER BY 1').fetchall()
   if expected!=actual:raise AssertionError('Records changed after in-place APK update: '+name+'.'+table)
   count+=1
  old.close();new.close()
 print(f'PASS: all {count} released tables, original IDs and photo bytes survived APK update.')
if __name__=='__main__':
 if sys.argv[1]=='create':create(sys.argv[2])
 elif sys.argv[1]=='compare':compare(sys.argv[2],sys.argv[3])
 else:raise ValueError('Unknown fixture operation')

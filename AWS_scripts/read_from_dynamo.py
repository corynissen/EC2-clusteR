import boto, sys

tablename = sys.argv[1]
hash_key = sys.argv[2]

# aws keys in /etc/boto.cfg, no need to put them here...
conn = boto.connect_dynamodb()
table = conn.get_table(tablename)
item = table.query(hash_key=hash_key, scan_index_forward=False, 
                   max_results=1)
print item.next_response()

# python read_from_dynamo.py 'cory_test' 'machineid1'

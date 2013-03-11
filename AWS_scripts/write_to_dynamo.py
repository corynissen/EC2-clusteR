import boto, sys

tablename = sys.argv[1]
messageid = sys.argv[2]
instanceid = sys.argv[3]
timestamp_pretty = sys.argv[4]
timestamp_int = sys.argv[5]

# aws keys in /etc/boto.cfg, no need to put them here...
conn = boto.connect_dynamodb()
table = conn.get_table(tablename)
item_data = {
        'messageid': messageid,
        'instanceid': instanceid,
        'timestamp': timestamp_pretty,
    }
item = table.new_item(hash_key=instanceid,range_key=int(timestamp_int), 
                      attrs=item_data)
item.put()

# python write_to_dynamo.py 'cory_test' 'messageid1' 'instanceid1', '12/9/2011 11:36:03 PM' 1362599095

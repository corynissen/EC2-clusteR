import boto, sys

tablename = sys.argv[1]
message_body = sys.argv[2]
output = sys.argv[3]
instanceid = sys.argv[4]
timestamp_pretty = sys.argv[5]
timestamp_int = sys.argv[6]

# aws keys in /etc/boto.cfg, no need to put them here...
conn = boto.connect_dynamodb()
table = conn.get_table(tablename)
item_data = {
        'message_body': message_body,
	'output': output,
        'instanceid': instanceid,
        'timestamp_pretty': timestamp_pretty,
    }
item = table.new_item(hash_key=instanceid,range_key=int(timestamp_int), 
                      attrs=item_data)
item.put()

# python write_output_to_dynamo.py 'cory_output_test' '{sample tweet here :)}' '1' 'instanceid1' '12/9/2011 11:36:03 PM' 1362599095

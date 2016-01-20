
with open('se_pa3_101.tr', 'r') as f :
 raw_lines = f.read().split('\n')
    
print("%s raw traces found." % (len(raw_lines)))
        
traces = []
for line in raw_lines :
    fields = line.split(' ')
    if fields[0] not in ['s', 'r', 'D'] :
      continue
    if not (fields[3] == 'MAC') :
      continue
    if not (fields[7] == 'cbr') :
      continue
                                            
    traces.append({'action': fields[0], 'node': fields[2], 'pid': int(fields[6])})
                                                
                                                
print("%s filtered traces found." % (len(traces)))

nodes = set(t['node'] for t in traces)
print("%s nodes found." % (len(nodes)))

sent = len(set(t['pid'] for t in traces))

#print("node_type:" % for t in traces t['node'])
#a = [t['pid'] for t in traces if t['node'] == "_10_"]
#print a
recv = len(set(t['pid'] for t in traces if t['node'] == "_0_" and t['action'] == "r"))

print("sent: %d, recv: %d, P: %.2f%%" % (sent, recv, float(recv)/sent*100))

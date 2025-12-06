#!/bin/python2
import pre_qc
import os
os.system('rm -rf object')
os.system('mkdir object')
#os.system('rm -rf pre_qc')
os.system('mkdir pre_qc')
# Skip chgrp if group doesn't exist (common in Docker containers)
os.system('chgrp quest object 2>/dev/null || true')
for line in file('locale_list'):
	r = pre_qc.run (line)
	if r == True:
		filename = 'pre_qc/'+line
	else:
		filename = line

	if os.system('qc '+filename):
		print 'Error occured on compile ' + line
		os.system('chmod -R 770 object')
		import sys
		sys.exit(-1)

os.system('chmod -R 770 object')

from bootstrapvz.base import Task
from bootstrapvz.common import phases
from bootstrapvz.common.tasks import packages


class AddNtpPackage(Task):
	description = 'Adding NTP Package'
	phase = phases.package_installation
	successors = [packages.InstallPackages]

	@classmethod
	def run(cls, info):
		info.packages.add('ntp')


class SetNtpServers(Task):
	description = 'Setting NTP servers'
	phase = phases.system_modification

	@classmethod
	def run(cls, info):
		import fileinput
		import os
		import re
		ntp_path = os.path.join(info.root, 'etc/ntp.conf')
		servers = list(info.manifest.plugins['ntp']['servers'])
		ubuntu_ntp_server = re.compile('.*[0-9]\.ubuntu\.pool\.ntp\.org.*')
		for line in fileinput.input(files=ntp_path, inplace=True):
			# Will write all the specified servers on the first match, then supress all other default servers
			if re.match(ubuntu_ntp_server, line):
				while servers:
					print 'server {server_address} iburst'.format(server_address=servers.pop(0))
			else:
				print line,

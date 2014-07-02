from bootstrapvz.base import Task
from bootstrapvz.common import phases
from bootstrapvz.common.tasks import packages
from bootstrapvz.common.tasks import apt
from bootstrapvz.common.tools import log_check_call
import logging


class AddRightlinkRepo(Task):
	description = 'Adding Rightscale repository'
	phase = phases.preparation

	@classmethod
	def run(cls, info):
		if info.source_lists.target_exists('rightscale'):
			msg = 'Rightscale repositories already present'
			logging.getLogger(__name__).info(msg)
		else:
			msg = 'Adding RightScale Repositories'
			logging.getLogger(__name__).info(msg)
			info.source_lists.add('rightscale-base',       'deb http://mirror.rightscale.com/rightscale_software_ubuntu/latest {system.release} main')
			info.source_lists.add('rightscale-rightlinlk', 'deb http://mirror.rightscale.com/rightlink/apt {system.release} main')

class AddRightScaleKey(Task):
	description = 'Add custom Rightscale Key'
	phase = phases.package_installation
	predecessors = [AddRightlinkRepo]
	successors = [apt.AptUpdate]

	@classmethod
	def run(cls, info):
		msg = 'Adding RightScale keys'
		logging.getLogger(__name__).info(msg)
		log_check_call(['chroot', info.root, 'wget','--quiet', 'http://s3.amazonaws.com/rightscale_key_pub/rightscale_key.pub', '-O', '/tmp/rs_key.pub'])
		log_check_call(['chroot', info.root, 'apt-key', 'add', '/tmp/rs_key.pub'])
		log_check_call(['shred', '--remove', info.root + '/tmp/rs_key.pub'])

class AddRightlinkPackage(Task):
	description = 'Adding Rightlink Package'
	phase = phases.package_installation
	predecessors = [AddRightScaleKey]

	@classmethod
	def run(cls, info):
		msg = 'Adding RightScale/rightlink packages'
		logging.getLogger(__name__).info(msg)
		info.packages.add('rightimage-extras-base')
		info.packages.add('rightlink-cloud-{provider}')



def main(opts):
	import sys
	sys.path.append(opts['PATH'])

	def walk_error(module):
		raise Exception('Unable to inspect module `{module}\''.format(module=module))
	classes = walk_classes([opts['PATH']], onerror=walk_error)
	print('\n'.join([str(obj) for obj in classes]))


def walk_classes(path=None, prefix='', onerror=None):
	import pkgutil
	import inspect
	import sys
	walker = pkgutil.walk_packages(path, prefix, onerror)
	for _, module_name, _ in walker:
		__import__(module_name)
		classes = inspect.getmembers(sys.modules[module_name], inspect.isclass)
		for class_name, obj in classes:
			if obj.__module__ == module_name:
					yield obj

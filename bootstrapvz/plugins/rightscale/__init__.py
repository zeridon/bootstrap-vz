def validate_manifest(data, validator, error):
	import os.path
	schema_path = os.path.normpath(os.path.join(os.path.dirname(__file__), 'manifest-schema.json'))
	validator(data, schema_path)


def resolve_tasks(taskset, manifest):
	import tasks
	if manifest.plugins['rightscale'].get('enable', False):
		taskset.add(tasks.AddRightlinkRepo)
		taskset.add(tasks.AddRightScaleKey)
		taskset.add(tasks.AddRightlinkPackage)

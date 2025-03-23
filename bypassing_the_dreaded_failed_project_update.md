From a **user**'s perspective, [AWX](https://github.com/ansible/awx) is a great tool! The UI is intuitive, it let's you set almost every *Ansible* parameter, it has projects that are synced from your *git* repos, it has workflows, it has an API, an *Ansible* collection to access it and it is robust.

Did I mention it syncs from your *git* repos? It does and it's great until it fails to update a project. If this happens, the templates of that project cannot be launched until the sync issue is resolved. This means that if you have a schedule to automatically update the project daily, there is a small risk that the update will fail and the other schedules  you might have will also fail. Unfortunately, as far as I know, you cannot disable this behavior. I have tried to add retries in a playbook that syncs the project and the inventory but it only made it a little bit safer. It's still risky.

The other day I manually updated a project and it failed because our self-hosted *Gitlab* instance was down due to an outage...and there were schedules to be run within a couple of hours...

## What does it look like

When a project fails on *AWX* 24.2 you get something like:
>> Missing a revision to run due to failed project update

and on *AWX* 15.1:

>> The project revision for this job template is unknown due to a failed update.

Then when a template is launched on *AWX* 24.2 you get:
>> ... RuntimeError: Missing a revision to run due to failed project update.

and on *AWX* 15.1 you get:

>> ... RuntimeError: The project revision for this job template is unknown due to a failed update.

## How to recover from a project sync failure

The easiest way to handle this, if we are not in a hurry, is to retry the project update when the outage is resolved :)

If we are in a hurry though, there is hope...we can update the *django* object of the project and make *AWX* think that the last update was actually successful:
1. delete the last failed sync job and retry the previous steps
2. enter the shell of a *AWX* web container:
```bash
# For docker-compose AWX deployments
docker exec -it tools_awx_1 bash
# For k8s AWX deployments
# Replace AWX_NAMESPACE with the namespace in which AWX has been deployed
kubectl get pod -n AWX_NAMESPACE
# Replace POD_NAME with one of the AWX pods from the previous command
kubectl exec -it -n AWX_NAMESPACE POD_NAME -c awx-web -- /bin/bash
```
3. enter the awx/django shell:
```bash
awx-manage shell
```
4. edit the project object:
```python
from awx.main.models import Project
# Find the project by name. Replace 'PROJECT_NAME' with the actual name of the project.
project = Project.objects.get(name='PROJECT_NAME')
# Change the status of the project
project.status = 'successful'
# Save the changes to the database
project.save()
```
5. refresh the project page. The status of the project will show a white circle (?).
6. try to launch a template from this project

Hopefully the issue is bypassed and the templates can be launched until the outage is resolved!

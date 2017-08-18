# Load Testing

## JMeter

Some customers use JMeter to load test GitLab. Here are instructions to set this up:

1. Create a Thread Group. Here is where you set the number of users and the ramp-up period.

    ![JMeter Therad Group](img/jmeter_thead_group.png)

2. Add a Random Variable element by right-clicking on Thread Group:

    ![JMeter Add Random Variable](img/jmeter_add_random_variable.png)

    ![JMeter Random Variable](img/jmeter_random_variable_page.png)

3. Add an HTTP Header element (right-click on Thread Group -> Add -> HTTP Header Manager):

    ![JMeter HTTP Header](img/jmeter_http_header_manager.png)

4. Add an HTTP request element. Fill in https if you are using HTTPS. Add the
hostname to Server Name field. Select POST as the request type, and
api/v4/projects?private_token=XXX. Add { "name": "${PROJECTNAME}" } as the
Body Data:

    ![JMeter HTTP Request](img/jmeter_http_request.png)

5. Add a Graph Results and View Results element to see output.

6. Click "Run" to run the test.

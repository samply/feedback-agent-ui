# Feedback agent UI
This is the UI for the feedback agent part of the metadata feedback system. It
provides a fontend that allows biobank administrators to associate metadata (e.g. the DOIs of relevant publications) with
locally held samples.

## Building for production
The feedback agent UI is designed to be run within a [Bridgehead](https://github.com/samply/bridgehead).
Before you start your Bridgehead, you will need to build a Docker container for this component:

``` code
git clone https://github.com/samply/feedback-agent-ui.git
cd feedback-agent-ui
docker build -t samply/feedback-agent-ui .
```

## Running the UI
If you just want to try out an isolated feedback agent UI (not in a Bridgehead), you can run a test instance locally.

### Docker
Build as shown above, and then:
``` code
docker run -p 8086:8086 samply/feedback-agent-ui
```
This will build the app and make it available on ```http://localhost:8086``` in a locally
running browser.

### Build and test with npm
If you have node.js and npm installed on your computer, you can run the UI on bare metal:
``` code
npm install
npm run serve
```
This will build the app and make it available on ```http://localhost:8086``` in a locally
running browser.

## Using the UI
When the UI first opens, you will see three data entry fields plus two buttons.

The first field is used for entering the ID of the measure report you are interested in.
This can be obtained from the locally running Blaze store.

Once you have entered the ID, you can click on the button "Get specimen list". Assuming
that a backend is available, you will shortly see a new query appearing in the second
data entry field. You can modify this query if you wish, or use as-is. To run the query,
click the button "Browse by query".

After a short delay, a list of specimens retrieved by the query will appear. You can
click in the check boxes to select the specimens relevant to you.

Finally, you can enter the ID of the string that you want to associate with the specimen in the
third field, and then press "Submit". This will initiate a polling process, by which the
central feedback hub will be asked if it has any tasks for the submitted ID.

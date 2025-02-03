<!--
This Vue component serves as a feedback interface for linking specimens with measure report IDs. 
The component includes:
  - An input field to enter a measure report ID and fetch associated specimens.
  - A field to input custom FHIR queries to search for specimens.
  - A checkbox table to select specimens for submission with a specified request ID.
  - A "Submit" button to send selected specimens to a feedback backend.

Key Features:
  - Polling functionality for asynchronous data retrieval.
  - Success and error alerts based on submission results.
  - API integration with FHIR queries and backend requests using Axios.

Dependencies:
  - Axios for HTTP requests.
  - CheckboxTable.vue for displaying selectable specimen data.

-->
<template>
  <div class="container text-center  mt-5 mb-5">
    <h1 class="mt-5 fw-bolder text-success "> Feedback Agent </h1>
    <p>
      This page is designed to link issued specimens from this bridgehead with ID of sample request.
       In the table there are local data displayed based on the provided query. You can insert ID of measure report in the first field to acquire its specimens.
       To link specimen with request ID select specimen by clicking checkbox in corresponding row of the table,
       enter the request ID into provided input form and click on "Submit" button.
    </p>
  </div>
  <div class="container">
    <div class="row mb-2">
      <div class="col-10">
        <input class="form-control" type="text" v-model="measureReportID" placeholder="Measure Report ID">
      </div>
      <div class="col-2">
        <button type="button" class="btn btn-primary" @click="fetchMeasureReportSpecimenListID(this.measureReportID)">
          <i class="bi bi-search" aria-label='Search Icon'></i>
          Get specimen list
        </button>
      </div>
    </div>
    <div class="row mb-2">
      <div class="col-10">
        <input class="form-control" type="text" v-model="query" placeholder="FHIR-Query">
      </div>
      <div class="col-2">
        <button type="button" class="btn btn-primary" @click="fetchSpecimen(this.query)">
          <i class="bi bi-search" aria-label='Search Icon'></i>
          Browse by query
        </button>
      </div>
    </div>
    <div class="row mb-2">
      <div class="col-12">
        <div class="table-wrapper table-responsive">
          <CheckboxTable v-if="file.length > 0" ref="checkBoxTable" :fields="fields" :tableData="file"></CheckboxTable>
        </div>
        <div class="d-flex justify-content-center">
          <div class="spinner-border text-primary" role="status" v-if="loading">
            <span class="sr-only">Loading...</span>
          </div>
        </div>
      </div>
    </div>
    <div class="row mb-4">
      <div class="col-7">
        <input class="form-control" type="text" v-model="requestID" placeholder="Request-ID">
      </div>
      <div class="col-2">
        <button type="submit" class="btn btn-success" @click="postSelected()" :disabled="requestID ==''">
          <i class="bi-file-earmark-medical" aria-label='Submit Icon'></i>
          Submit
        </button>
      </div>
      <div class="col-3">
        <div class="alert alert-success" role="alert" v-if="enableSuccessAlert">
          Selected entries uploaded successfully.
        </div>
        <div class="alert alert-danger" role="alert" v-if="enableDangerAlert">
          Alert: failed to upload entries.
        </div>
      </div>
    </div>
  </div>
</template>
<script>
// Importing http client
import axios from 'axios'
// Importing the table component
import CheckboxTable from './components/CheckboxTable.vue'

export default {
  name: 'App',
  components: {
    CheckboxTable,
  },
  data() {
    return {
        query: "Specimen?subject=Patient/bbmri-18&type=rna",
        measureReportID: "",
        requestID : "",
        x_api_key: '', // API key for the exporter. Get this from backend.
        exportTemplate: "bbmri-feedback-agent",
        exportListIDTemplate: "bbmri-measure-report-specimen-list",
        file: "",
        content: [],
        enableSubmit: false,
        enableSuccessAlert: false,
        enableDangerAlert: false,
        fields: [],
        loading: false
    }
  },
  methods: {
    /**
     * Fetches the x_api_key from a secure API endpoint.
     */
    fetchApiKey() {
      const apiUrl = process.env.VUE_APP_FB_BACKEND_URL;
      const apiKeyUrl = `${apiUrl}/exporter-api-key`;

      // Use axios to fetch the API key
      axios.get(apiKeyUrl)
        .then(response => {
          //this.x_api_key = response.data.apiKey; // Ensure the response contains the key as `apiKey`
          this.x_api_key = response.data;
        })
        .catch(error => {
          console.error("Error fetching x_api_key:", error);
        });
    },
    /**
     * Fetches the specimen list ID for a given measure report ID.
     * It sends a POST request to the exporter API with the encoded measure report ID.
     * It uses an API key (x_api_key) for authentication.
     * On successful response, it awaits the list from the provided response URL.
     */
    fetchMeasureReportSpecimenListID() {
      this.content.data = [];
      if (this.x_api_key === null || this.x_api_key === "") {
        console.error("no API key available for Exporter");
      } else {
        axios.defaults.headers['X-API-KEY'] = this.x_api_key;
      }
      
      // Encode the query string before appending it to the URL
      const encodedQuery = encodeURIComponent(`MeasureReport?_id=${this.measureReportID}`);

      // Construct the URL with the encoded query
      const apiUrl = process.env.VUE_APP_EXPORTER_URL;
      const requestUrl = `${apiUrl}/request?query=${encodedQuery}&query-format=FHIR_SEARCH&template-id=${this.exportListIDTemplate}&output-format=JSON`;

     // Send a POST request to the constructed URL
     axios.post(requestUrl)
        .then(response => {
          // Successful response
          this.awaitList(response.data.responseUrl);
          console.log("List available");
        })
        .catch(error => {
          // Log any errors encountered during the request
          console.error("fetchMeasureReportSpecimenListID: Error fetching specimen ID list:");
          console.error("fetchMeasureReportSpecimenListID: requestUrl:", requestUrl);
          if (!this.x_api_key) {
            console.error("fetchMeasureReportSpecimenListID: x_api_key is not defined");
          }
          console.error("fetchMeasureReportSpecimenListID: error:", error);
        });
    },
    /**
     * Fetches the specimen list for a given query.
     * It sends a POST request to the exporter API with the query and template id.
     * It uses an API key (x_api_key) for authentication.
     * On successful response, it awaits the list from the provided response URL.
     */
    fetchSpecimen() {
      this.content.data = [];
      axios.defaults.headers['X-API-KEY'] = this.x_api_key;

      // Don't bother fetching a Specimen if this.query is empty
      if (this.query === "") {
        return;
      }
      
      // Encode the query string before appending it to the URL
      const encodedQuery = encodeURIComponent(this.query);

      // Construct the URL with the encoded query
      const apiUrl = process.env.VUE_APP_EXPORTER_URL;
      const requestUrl = `${apiUrl}/request?query=${encodedQuery}&query-format=FHIR_SEARCH&template-id=${this.exportTemplate}&output-format=JSON`;

      axios.post(requestUrl)
        .then(response => {
          this.awaitForSamples(response.data.responseUrl);
        })
        .catch(error => {
          // Log any errors encountered during the request
          console.error("Error fetching specimen:", error);
        });
    },
    // polling, because data are not availible right away, exporter takes some time to generate files
    awaitList(JSONUrl) {
      axios.defaults.headers['X-API-KEY'] = null;
      const pollInterval = 5000; // 5000 milliseconds
      const maxPollAttempts = 10;
      let pollAttempts = 0;
      this.query = "";
      this.loading = true;

      /**
       * This function repeatedly sends a GET request to JSONUrl until it receives a successful response or reaches the maximum number of attempts.
       * If the response is successful (200 status code) and contains a SpecimenList, it extracts the listID from the first entry and updates this.query.
       * If the response is not successful or does not contain a SpecimenList, it increments the attempt counter and retries after a specified interval (pollInterval).
       * If the maximum number of attempts (maxPollAttempts) is reached, it stops polling and logs a message.
       * The function also catches and logs any errors that occur during the polling process, and retries after the specified interval.
       */
      const poll = () => {
        axios.get(JSONUrl)
          .then(response => {
            if (response.status === 200 && response.data && response.data.SpecimenList) {
              console.log(response);
              const specimenList = response.data.SpecimenList;

              if (specimenList.length > 0) {
                // take the first entry and extract the listID
                const firstEntry = specimenList[0];
                if (firstEntry.listID && typeof firstEntry.listID === 'string') {
                  // strip "List/" from the listID and save it to this.query
                  this.query = firstEntry.listID.replace('List/', 'Specimen?_list=');
                }
              }

              // Stop polling since the response is available
              this.loading = false;
              return;
            }

            // Increment pollAttempts and check if we have reached the maximum attempts
            pollAttempts++;
            if (pollAttempts >= maxPollAttempts) {
              console.log("Exceeded maximum poll attempts");
              this.loading = false;
              return;
            }

            // Retry after the polling interval
            setTimeout(poll, pollInterval);
          })
          .catch(error => {
            console.error("Error while polling for JSON:", error);
            // Retry after the polling interval
            setTimeout(poll, pollInterval);
          });
      };

      poll();
    },
  /**
   * Fetches the list of samples from the provided JSON URL.
   * It sends a GET request to the URL and waits for the response.
   * If the response is successful and contains the 'Samples' key,
   * it extracts the sample list and assigns it to this.file.
   * If the response is not successful, it retries after a polling interval.
   * It gives up after a maximum number of poll attempts.
   * @param {string} JSONUrl - URL to poll for the list of samples
   */
    awaitForSamples(JSONUrl) {
      axios.defaults.headers['X-API-KEY'] = null;
      const pollInterval = 5000; // 5000 milliseconds
      const maxPollAttempts = 10;
      let pollAttempts = 0;
      this.file = "";
      this.loading = true;

      const poll = () => {
        axios.get(JSONUrl)
          .then(response => {
            if (response.status === 200 && response.data) {
              console.log(response);
              this.file = response.data.Samples.map((sample) => ({
                ...sample,
                sampleID: sample.sampleID.replace('Specimen/', ''),
              }));
              console.log(this.file);
              if (this.file.length > 0) {
                // Extract keys from the first object in the Samples array
                this.fields = Object.keys(this.file[0]);
              }

              // Stop polling since the response is available
              this.loading = false;
              return;
            }

            // Increment pollAttempts and check if we have reached the maximum attempts
            pollAttempts++;
            if (pollAttempts >= maxPollAttempts) {
              console.log("Exceeded maximum poll attempts");
              this.loading = false;
              return;
            }

            // Retry after the polling interval
            setTimeout(poll, pollInterval);
          })
          .catch(error => {
            console.error("Error while polling for JSON:", error);
            // Retry after the polling interval
            setTimeout(poll, pollInterval);
          });
      };

      poll();
    },
    /**
     * Sends selected data to the local FBagent database.
     * This method sends a POST request to the backend API (VUE_APP_FB_BACKEND_URL)
     * with selected data from a checkbox table (checkBoxTable). It adds a requestID
     * to each selected item and displays a success or error alert based on the
     * response status.
     */
    postSelected() {
        // Reset alert flags
      this.enableSuccessAlert = false;
      this.enableDangerAlert = false;

      // Retrieve selected data from the checkbox table
      let postData = this.$refs.checkBoxTable?.selected();
      if (!postData) {
        console.error("Error: Selected data is null or undefined");
        this.enableSuccessAlert = false;
        this.enableDangerAlert = true;
        return;
      }

      // Add requestID to each selected item
      postData.forEach((element) => {
        element.requestID = this.requestID;
      });

      // Construct API URL
      //const apiUrl = process.env.VUE_APP_FB_BACKEND_URL;
      const apiUrl = `${process.env.VUE_APP_FB_BACKEND_URL}/multiple-specimen-feedback`;
      console.log("API URL:", apiUrl);

      // Send POST request with feedbackList
      const headers = {
        "Content-Type": "application/json",
      };
      axios.post(apiUrl, JSON.stringify({ feedbackList: postData }), { headers })
        .then(response => {
          if (response.status == 200) {
            // Show success alert
            this.enableSuccessAlert = true;
            this.enableDangerAlert = false;
          } else {
            console.error("Problem with multiple-specimen-feedback, status:", response.status);
            // Show error alert
            this.enableSuccessAlert = false;
            this.enableDangerAlert = true;
          }
        })
        .catch(error => {
          // Log any errors encountered during the request
          console.error("Error with multiple-specimen-feedback:", error);
          // Show error alert
          this.enableSuccessAlert = false;
          this.enableDangerAlert = true;
        });
    }
  },

  /**
   * Call fetchApiKey when the component is created to ensure x_api_key is loaded.
   */
  created() {
    this.fetchApiKey();
  }
}
</script>

<style>
#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: left;
  color: #2c3e50;
}
.table-wrapper {
  max-height: 500px;
}
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0,0,0,0);
  border: 0;
}
</style>


# WorkoutKit demo app

## Overview
This demo app demonstrates how to retrieve a list of workout sessions and run it on the training interface offered by WorkoutKit.

## Getting started guide
The getting started guide is available as part of the WorkoutKit documentation. More info [here](../../README.md).

## GraphQL Client Generation (DemoCloud package)

We use ApolloGraphQL library to generate **DemoCloud** package with items described in .graphql files.

### Install CLI
- Open the sample app in Xcode.
- Right click on SampleApp at the top of the left panel. Then choose Apollo > Install CLI.
- Authorize execution and writing on alerts.

### Commands
In your terminal run following commands to fetch the schema from the server.

Don't forget to update `endpointURL` in `apollo-codegen-config.json` with the server our team provided just for you.
An optional "X-Developer-Authorization-Key" may be needed to retrieve schema.

#### Fetch schema
`./apollo-ios-cli fetch-schema --path SampleApp/apollo-codegen-config.json`

#### Generate client
`./apollo-ios-cli generate --path SampleApp/apollo-codegen-config.json`

## Running the app
You need to update the server URL in `DemoCloudClient.swift` file with the one our team provided.

You also need an "Authorization" header if required by your platform. You can add it in `DemoCloudClient.swift` file under `DemoHeadersAddingInterceptor`.

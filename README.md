# cg-diff

## Reproducing Experiments

Pull and run the docker image by executing

`docker run -p 5000:5000 aianta/cg-diff`

Navigate to `http://localhost:5000`. The application may take a while to load in the browser as it has to load ~135MB of data. 

You can now select the graphs you wish to difference from the drop down menus under g1 and g2. 

In the final report we tested the following configruations:

| G1 | G2 |
|-|-|
|hello world | hello world with system property |
|hello world with system property | hello world with read file |
|hello world with stream | hello world with stream and string builder |
|hello world | hello world with stream |

For the final report we ran each configuration 5 times copying and pasting the 'compute time' value into an excel spreadsheet (available in the repository) which computed the mean median and standard deviation. The experiment was run on a machine with an Intel i9-9900K processor @5.0GHz with 64GB of RAM. It is normal for the page to crash after several executions in a row, when this happens simply reload the page to continue.

## Building/Running from the repo

Everything required to reproduce the experiements in the final report is bundled into a docker image available from Docker Hub. You should only need to download this repository if you want to modify the implementation of the visualization, or add/modify the bundled datasets. The instructions on how to setup/run the project are below.

All the data for the experiments is located in the `src/data/` folder, and imported at the start of the script tag in `src/App.vue`. Once imported simply add your new data to the `dataOptions` array and your dataset should appear in the dropdown menu upon (hot)reload. 


## Project setup
```
npm install
```

### Compiles and hot-reloads for development
```
npm run serve
```

### Compiles and minifies for production
```
npm run build
```

### Lints and fixes files
```
npm run lint
```

### Customize configuration
See [Configuration Reference](https://cli.vuejs.org/config/).

const PANEL_ID = "catfacts.panel@margaretleibovic.com";
const DATASET_ID = "catfacts.dataset@margaretleibovic.com";
const DATA_URL = "http://catfacts-api.appspot.com/api/facts?number=20";
//
function optionsCallback() {
    return {
    title: Strings.GetStringFromName("title"),
    views: [{
            type: HomePanels.View.LIST,
            dataset: DATASET_ID,
            onrefresh: refreshDataset
            }]
    };
}
//
function refreshDataset() {
    fetchData(DATA_URL, function(response) {
              Task.spawn(function() {
                         let items = JSON.parse(response).facts.map(function(fact) {
                                                                    return {
                                                                    url: "http://catfacts-api.appspot.com/",
                                                                    description: fact
                                                                    };
                                                                    });
                         let storage = HomeProvider.getStorage(DATASET_ID);
                         yield storage.deleteAll();
                         yield storage.save(items);
                         }).then(null, e => Cu.reportError("Error refreshing dataset " + DATASET_ID + ": " + e));
              });
}

//function deleteDataset() {
//    Task.spawn(function() {
//               let storage = HomeProvider.getStorage(DATASET_ID);
//               yield storage.deleteAll();
//               }).then(null, e => Cu.reportError("Error deleting data from HomeProvider: " + e));
//}

/**
 * bootstrap.js API
 * https://developer.mozilla.org/en-US/Add-ons/Bootstrapped_extensions
 */
//function startup(data, reason) {
//    HomePanels.install("test")

    // Always register your panel on startup.
//    HomePanels.register(PANEL_ID, optionsCallback);
//
//    switch(reason) {
//        case ADDON_INSTALL:
//        case ADDON_ENABLE:
//            HomePanels.install(PANEL_ID);
//            refreshDataset();
//            break;
//
//        case ADDON_UPGRADE:
//        case ADDON_DOWNGRADE:
//            HomePanels.update(PANEL_ID);
//            break;
//    }
//    
    // Update data once every hour.
//    HomeProvider.addPeriodicSync(DATASET_ID, 3600, refreshDataset);
//}

//function shutdown(data, reason) {
//    if (reason == ADDON_UNINSTALL || reason == ADDON_DISABLE) {
//        HomePanels.uninstall(PANEL_ID);
//        deleteDataset();
//    }
//    
//    HomePanels.unregister(PANEL_ID);
//}

//function install(data, reason) {}

//function uninstall(data, reason) {}

function startup() {
    HomePanels.install("test")
}


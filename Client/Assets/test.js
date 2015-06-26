const PANEL_ID = "catfacts.panel@margaretleibovic.com";
const DATASET_ID = "catfacts.dataset@margaretleibovic.com";
const DATA_URL = "http://catfacts-api.appspot.com/api/facts?number=20";

function optionsCallback() {
    return {
    title: "title",
//    title: Strings.GetStringFromName("title"),
    views: [{
            type: HomePanels.View.LIST,
            dataset: DATASET_ID,
            onrefresh: refreshDataset
            }]
    };
}

function refreshDataset() {
//    fetchData(DATA_URL, function(response) {
//              Task.spawn(function() {
//                         let items = JSON.parse(response).facts.map(function(fact) {
//                                                                    return {
//                                                                    url: "http://catfacts-api.appspot.com/",
//                                                                    description: fact
//                                                                    };
//                                                                    });
//                         let storage = HomeProvider.getStorage(DATASET_ID);
//                         yield storage.deleteAll();
//                         yield storage.save(items);
//                         }).then(null, e => Cu.reportError("Error refreshing dataset " + DATASET_ID + ": " + e));
//              });
}

function startup(data, reason) {
    // Always register your panel on startup.
    HomePanels.register(PANEL_ID, {
        title: "title",
        views: [{
                type: HomePanels.View.LIST,
                dataset: DATASET_ID,
                onrefresh: refreshDataset
                }]
        });

//    HomePanels.register(PANEL_ID, optionsCallback);

    switch(reason) {
        case ADDON_INSTALL:
        case ADDON_ENABLE:
            HomePanels.install(PANEL_ID);
            refreshDataset();
            break;

        case ADDON_UPGRADE:
        case ADDON_DOWNGRADE:
            HomePanels.update(PANEL_ID);
            break;
    }

    // Update data once every hour.
//    HomeProvider.addPeriodicSync(DATASET_ID, 3600, refreshDataset);
}
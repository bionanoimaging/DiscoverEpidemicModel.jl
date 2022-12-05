function grabArcGISData(url::String)
    startDate = Dates.Date(2020, 1, 1)
    endDate = Dates.today() + Dates.Day(1)
    dfs = []
    dataRange= collect(startDate:Dates.Day(1):endDate)
    for singleDate in dataRange[1:4]
        print("reading: " * string(singleDate) * "\n")
    end
        #with urllib.request.urlopen("https://services7.arcgis.com/mOBPykOjAyBO2ZKk/arcgis/rest/services/RKI_COVID19/FeatureServer/0//query?where=Meldedatum%3D%27" + str(single_date.strftime("%Y-%m-%d")) + "%27&objectIds=&time=&resultType=none&outFields=*&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnDistinctValues=false&cacheHint=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&sqlFormat=none&f=pjson&token=") as url:
        #    json_data = json.loads(url.read().decode())["features"]
        #json_data = [x["attributes"] for x in json_data if "attributes" in x]
        #if len(json_data) > 0:
        #    dfs.append(pd.DataFrame(json_data))
    
end

function getData(uri::String)
    myData=HTTP.request("GET", uri)
    return myData
    
end
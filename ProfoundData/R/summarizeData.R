
#' @title A function to summarize data from the database
#'
#' @description  This function allows to summarize datasets for a location
#' from the PROFOUND database.
#' @param location a character string providing the name of the location
#' @param dataset a character string providing the name one of the available
#'  climatic datasets (CLIMATE_LOCAL, CLIMATE_ISIMIP, ...) or the tree dataset
#' @param by a character string indicating how summarize the data. Currently supports
#' by year and total. The latter refers to the entire available period.
#' @param forcingDataset a character string providing the name of the a forcingDataset.
#' Only relevant for ISIMIP datasets.
#' @param forcingCondition a character string providing the name of the a forcingCondition.
#' Only relevant for ISIMIP datasets.
#' @param period a character array either start of the subset or start and end.
#'  It must have the format YYYY-MM-DD.
#' @param mode a character string whether to display the data summary or an overview.
#' @details This function is under development and has limited fucntionality. At the
#' moment, it is possible to summarize daily climate datasets and tree data.
#' @return a dataframe with the summary values
#' @keywords ProfoundData
#' @note To report errors in the package or the data, please use the issue tracker
#' in the github repository of TG2 https://github.com/COST-FP1304-PROFOUND/TG2/issues
#' (preferred, but requires that you have access to our GitHub account) or
#' or use this google form http://goo.gl/forms/e2ZQCiZz4x
#' @section Summary values: Summary is calculated by year
#' \itemize{
#'   \item Climatic datasets
#'   \itemize{
#'    \item  p_mm and rad_Jcm2day are total yearly values
#'    \item  tmax_degC,  tmean_degC, tmin_degC, relhum_percent, airpress_hPa  and wind_ms are mean yearly values
#'    }
#'   \item TREE dataset
#'    \itemize{
#'    \item density_treeha is the number of tree per ha
#'    \item dbhArit_cm is the arithmetic mean diameter
#'    \item dbhBa_cm is the average diameter weighted by basal area calculated as dbhBA = (ba1*dbh1 + ba2*dbh2 + ... + bak*dbhk) / (ba1 + ba2+ ... + bak), where bai and dbhi are the basal area and dbh, respectively, of the tree i, and  i = 1, 2, . . , k
#'    \item dbhDQ_cm is the mean squared diameter or quadratic mean diameter calculated as dbhDQ = sqrt( (dbh1^2 + dbh2^2+ ... + dbhk^2) / N),  where dbhi is the diameter at breat height of tree i,   i = 1, 2, . . , k, N is the total number of trees, and sqrt is the square root
#'    \item heightArith_m is the arithmetic mean height
#'    \item heightArith_m is the verage height weighted by basal area or Loreys height calculated as heightBA = (ba1*h1 + ba2*h2 + ... + bak*hk) / (ba1 + ba2+ ... + bak), where bai and hi are the basal area and height, respectively, of the tree i, and  i = 1, 2, . . , k
#'    \item heightBA_m
#'    \item ba_m2 is the basal area per hectare
#'    }
#' }
#' @details Data are summarized by years. Radiation and precipation are provided as total yearly
#' values, while the rest of climatic values are year mean values.  For ISIMIP datasets a summary for whole
#' period will be returned if the dataset comprises more than one forcing datasets and one forcing conditions.
#'
#' @export
#' @examples
#' \dontrun{
#' summarizeData("CLIMATE_ISIMIP2B", location = "Soro")
#' summarizeData("CLIMATE_LOCAL", location = "Soro")
#' summarizeData("TREE", location = "Soro")
#' }
#' @author Ramiro Silveyra Gonzalez
summarizeData <- function(dataset, location,  forcingDataset = NULL,
                          forcingCondition = NULL,  by = "year",  period = NULL,
                          mode = "data"){
  if (!by %in% c("year", "total", "day" )) stop("Invalid by value")

  if (!mode %in% c("data", "overview" )) stop("Invalid mode value")

  message("Parsing the query")
  tmp <- try(parseQuery(dataset=dataset, location=location, forcingDataset = forcingDataset,
                        forcingCondition = forcingCondition,collapse = T, period = period), F)
  if ('try-error' %in% class(tmp))    stop("Could not parse the query")
  # get Data
  if (tmp[["dataset"]] == "SITES")  stop("Can't summarize SITES")
  #message(paste("Downloading data from" , tmp[["dataset"]], "for the location", location,  sep = " "))
  tmp <- try(fetchQuery(tmp), F)
  if ('try-error' %in% class(tmp))    stop("Could not fetch the query")
  data <- formatData(tmp)

  if (mode == "data"){
    if (tmp[["dataset"]] == "CLIMATE_LOCAL"){
      data <- summarizePROFOUND.CLIMATE(data, by = by)
    }else if(grepl("CLIMATE_ISIMIP", tmp[["dataset"]])){
      data <- summarizePROFOUND.ISIMIP(data, by = by)
    }else if(tmp[["dataset"]] == "TREE"){
      data <- summarizePROFOUND.TREE(data)
    }else if(tmp[["dataset"]] == "FLUX"){
      data <- summarizePROFOUND.FLUX(data, by = by)
    }else{
      stop("Can't summarize the dataset")
    }
  }else if (mode == "overview"){
    if(tmp[["dataset"]] == "STAND"){
    data <- startStopPROFOUND.STAND(data)
    }else if(tmp[["dataset"]] == "FLUX"){
      data <- summarizePROFOUND.FLUX(data, by = "year")
      data <- startStopPROFOUND.YEARLY(data)
    }else if (tmp[["dataset"]] == "CLIMATE_LOCAL"){
      data <- summarizePROFOUND.CLIMATE(data, by = "year")
      data <- startStopPROFOUND.YEARLY(data)
    }else if (grepl("CLIMATE_ISIMIP", tmp[["dataset"]])){
      data <- startStopPROFOUND.ISIMIP(data)
    }else{
      stop("Can't summarize the dataset")
    }
  }else{
    stop("Wrong model value")
  }
  return(data)
}


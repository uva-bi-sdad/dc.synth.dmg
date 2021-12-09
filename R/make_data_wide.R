make_data_wide <- function (df) 
{
  df_copy <- data.table::copy(df)
  dt <- data.table::setDT(df_copy)
  data.table::dcast(dt, rpc_master + geoid + year ~ measure, value.var = "value", fun.aggregate = sum)
}

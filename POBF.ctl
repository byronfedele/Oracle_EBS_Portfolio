LOAD DATA
INFILE *
APPEND
INTO TABLE PURCHASE_ORDERBF_STG
FIELDS TERMINATED BY "," 
OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
(
vendor_number,
document_type_code,
agent_number,
bill_to_location,
ship_to_location,
curr_code,
inventory_item,
unit_of_measure,
unit_price,
quantity,
line_number, 
record_status       CONSTANT 'NEW')

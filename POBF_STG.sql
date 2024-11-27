DROP TABLE purchase_orderBF_stg;
CREATE TABLE purchase_orderBF_stg (
                                              vendor_number                  VARCHAR2 ( 30 )  -- Supplier number
                                            , document_type_code             VARCHAR  ( 10 )  -- Document Type
                                            , agent_number                   VARCHAR2 ( 30 )  -- Employee Name from per_all_people_f table
                                            , agent_name                     VARCHAR2 ( 240 ) -- Employee full name
                                            , bill_to_location               VARCHAR2 ( 30 )  -- Ship to location code
                                            , ship_to_location               VARCHAR2 ( 30 )  -- Bill to location code
                                            , action                         VARCHAR2 ( 20 )  -- Required action
                                            , curr_code                      VARCHAR2 ( 10 )  -- Currency_code
                                            , inventory_item                 VARCHAR2 ( 30 )  -- Inventory item name
                                            , item_description               VARCHAR  ( 240 ) -- Inventory item description
                                            , unit_of_measure                VARCHAR2 ( 15 )  -- Unit of measure for item
                                            , unit_price                     NUMBER           -- Unit price of item
                                            , quantity                       NUMBER           -- Ordered quantity of items
                                            , need_by_date                   DATE             -- Need by date for purchase order
                                            , line_number                    VARCHAr2(5)           -- Line number for item ordered
                                            , org_id                         NUMBER
                                            , vendor_id                      NUMBER
                                            , ship_to_location_id            NUMBER
                                            , bill_to_location_id            NUMBER
                                            , inventory_item_id              NUMBER
                                            , batch_id                       NUMBER
                                            , created_by                     NUMBER
                                            , creation_date                  DATE
                                            , last_updated_by                NUMBER
                                            , last_updated_date              DATE
                                            , last_updated_login             NUMBER
                                            , request_id                     NUMBER
                                            , record_status                  VARCHAR2  ( 10 )
                                            , error_message                  VARCHAR2  ( 2000 )
                                            );

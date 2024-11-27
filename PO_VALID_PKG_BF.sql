
create or replace package PO_VALID_PKG_BF as
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Package for Inserting Data from Staging table to Interface Table
-- Author  : SUNDAR
-- Package Specification and Body PO_VALID_PKG_BF
-- History----Version---Author---Comment
-- 28/4/2015   1.0      SUNDAR     Current as per specification provided
--
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- This procedure will validate and Insert data into Purchasing Interface table
   
   Procedure main (p_errbuf  OUT NOCOPY Varchar2,
                   p_retcode OUT NOCOPY Number);
   Procedure Validate_Currency_BF(p_curr_code fnd_currencies.CURRENCY_CODE%Type,P_ret_txt OUT Number );
   Function  Get_VendorID_BF(p_vendor_num ap_suppliers.segment1%type ) return number;
   function  get_EmployeeId_BF(p_agent_number per_all_people_f.employee_number%type)     return number;
   function  get_inventory_itemId_BF(p_inv_item mtl_system_items.segment1%type )         return number;
   function  get_vendor_siteId_BF(p_vendor_id ap_suppliers.vendor_id%type) 
                 return varchar2;
function get_inventory_itemDscr_BF(p_inv_item mtl_system_items.segment1%type )
                           return varchar2;                 
end PO_VALID_PKG_BF;

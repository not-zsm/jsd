export type PermissionSettings = {
	mode: ("Web" | "Product")?;
	refresh_time: number?;
	invalidate_out_of_date_whitelist: number?;
	web_repository: string?;
	product_id: number?;
};

return {};
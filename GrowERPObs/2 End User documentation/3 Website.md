# Website Introduction

The system generates a website for every company/admin which can be viewed by using the internet address as is shown on top of the website maintenance page in the main menu company section.

This website can be used as a normal textual website where you introduce yourself or your company and provide regular information via an optional blog and can be used as a full e-commerce website where you can sell products and which can be ordered by visitors at the website.

A payment gateway is built-in. You need to provide your bank account in order to receive the ordered products on a monthly basis.

The website is maintained by the 'admin' application. on the dashboard -> company website screen. This screen will give you the internet address you an enter in the browser to show the website.

![[media/websiteAdmin.png]]  ![[media/website.png]]

## Website Logo.

The logo at the top-left of the website can be changed by uploading an image at the admin dashboard -> Company -> company info screen

## Website title.

At the website admin screen as shown above, you can change the title of the website

## website address.

You receive a free subdomain name and free https certificate by using this system of which you can change the first part. It is also possible to use your own domain name for an extra charge.

## Text Sections.

Text sections are in [markdown format](https://www.markdownguide.org/cheat-sheet/) and can be added and deleted at will. The title of the text page will appear as a menu item in the header of the website. Further an automatic content list is generated making use of the markdown '#' and '##' headers. Initially example page are generated to help you get started. You can delete them all if you do not want to use them.

An exception is the text section page which starts with 'home'. This page will not show in the menu but will appear at the homepage when present. With this page you can create a text only website if remove all the references to categories and products from the website.

You can also include images within the text with the following code: 
```
![](/getImage/xxxx) where 'xxxx' are the first few characters of the image name.
```
## Images.

Here you can upload the images for use within the text section pages. Give it a unique name because you need it to insert in the test section.

## Home Page categories.

The home will show products in two rows as indicated by the 'home page categories'

If you click on the deals or features button you can add specific categories to be show here. If no products are assigned the row will not show.

## Shop drop-down categories.

If you have a lot of products it is advised to create categories in the admin dashboard -> catalog -> categories screen and group your products here.

The categories you created can be added to this section show them in the 'shop' dropdown. If no categories are assigned the 'shop' option will not show.

## promote on other platforms.

If you like to promote a single product on other platforms, go to your own website here and click on the product. Now copy the full internet address at the top of your browser and past it as a link in the text you created somewhere else.

## Obsidian upload
You can upload an obsidian vault which will be displayed in Html at the website as an option on the tab bar.

This is provided to have a documentation website of your products or services.
Only some Obsidian features are supported.

1. Links to local pages or external pages
2. inclusion of local images
3. Inclusion of external markdown files with the example code:
``` 
	![](https://example.com/your md file page.md )
```

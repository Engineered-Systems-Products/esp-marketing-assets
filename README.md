# ESP Marketing Assets

Public image host for Engineered Systems & Products marketing posts.

Images in `images/` are served over HTTPS at:

```
https://engineered-systems-products.github.io/esp-marketing-assets/images/<filename>
```

This exists because Instagram's Content Publishing API will only accept a publicly
reachable image URL — it has no file-upload option. Hosting the images here keeps that
public surface entirely on GitHub's infrastructure.

## Adding an image

```powershell
.\add-image.ps1 -Path "C:\path\to\photo.jpg"
```

It normalises the filename, checks the image against Instagram's limits, commits, pushes,
and prints the public URL.

## What belongs here

Only finished marketing images that are meant to be seen publicly — product photos,
installation shots, branded graphics, logos.

## What must never be committed here

**This repository is public. Anything committed is world-readable, and stays in the git
history even after deletion.**

- Customer or contact information of any kind — names, sites, phone numbers, email
- Pricing, quotes, bids, purchase orders, invoices, or contracts
- Screenshots of social media pages, inboxes, or CRM screens — these routinely capture
  other people's names, comments, and profile photos
- Employee personal information
- Drawings, specifications, or submittals belonging to a customer or engineer
- Credentials, API keys, or access tokens

If you are unsure whether an image is safe to publish, it does not go here.

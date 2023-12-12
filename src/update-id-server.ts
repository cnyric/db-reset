import { RefinedDistrict } from '@@types';

import { expect } from '@playwright/test';
import { chromium } from 'playwright';
import { log } from './util.js';

async function updateIdServer(district: RefinedDistrict) {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext({ ignoreHTTPSErrors: true });
  const page = await context.newPage();

  await page.goto(district.training as string);

  const user = await page.$('#Template1_MenuList1_TextBoxUsername');
  await user?.fill(process.env.SCHOOLTOOL_USER as string);

  const pass = await page.$('#Template1_MenuList1_TextBoxPassword');
  await pass?.fill(process.env.SCHOOLTOOL_PASSWORD as string);

  await page.click('input:has-text("Login")');

  await page.waitForURL(`${district.training as string}/`, {
    waitUntil: 'networkidle'
  });

  await page.click('#Template1_MenuList1_DataList_Tabs_ctl10_SchoolToolLink_Tab');
  await page.click('#Template1_MenuList1_DataList_Tabs_ctl10_RepeaterTabSubMenu_ctl01_SchoolToolLink_Menu');
  await page.click('#Template1_Control0_SelectList1_ctl38');

  const idServer = await page.$('#SiteNameTextbox');
  await idServer?.fill(district.database);
  const connectButton = await page.$('button.connect-button');
  await connectButton?.click();

  expect(await connectButton?.innerText()).toBe('CONNECTED');
}

export default updateIdServer;

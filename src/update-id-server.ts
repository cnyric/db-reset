import { RefinedDistrict } from '@@types';
import { chromium } from 'playwright';
import { expect } from '@playwright/test';
import { log } from './util.js';

async function updateIdServer(district: RefinedDistrict) {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ ignoreHTTPSErrors: true });
  const page = await context.newPage();

  await page.goto(district.training as string);

  const user = await page.$('#Template1_MenuList1_TextBoxUsername');
  await user?.fill(process.env.SCHOOLTOOL_USER as string);

  const pass = await page.$('#Template1_MenuList1_TextBoxPassword');
  await pass?.fill(process.env.SCHOOLTOOL_PASSWORD as string);

  await page.click('input:has-text("Login")');

  const maintenance = page.getByRole('link', { name: 'Maintenance' });
  await maintenance?.waitFor();
  await maintenance.click();
  await page.getByRole('link', { name: 'Application' }).click();
  await page.click('#Template1_Control0_SelectList1_ctl38');

  const connectButton = await page.$('button.connect-button');
  expect(await connectButton?.innerText()).toBe(' CONNECT');

  const idServer = await page.$('#SiteNameTextbox');
  await idServer?.fill(district.database);

  await connectButton?.click();

  setTimeout(async () => {
    expect(await connectButton?.innerText()).toBe('CONNECTED');
  }, 3000);
}

export default updateIdServer;

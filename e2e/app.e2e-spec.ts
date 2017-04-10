import { E2ETesting } from './app.po';

describe('Functional Testing for the target website', () => {
  let page: E2ETesting;

  beforeEach(() => {
    page = new E2ETesting(process.env.TARGET_TESTING_SITE);
    page.navigateTo();
  });

  // add more test cases
  it('should be on the landing page', () => {
    // do something ...
  });
});

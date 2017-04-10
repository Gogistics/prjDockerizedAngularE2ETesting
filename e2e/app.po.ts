import { browser, element, by } from 'protractor';
class BaseOfE2ETesing {
  // inner variables
  private testingUrl: string;

  // constructor
  constructor (givenUrl: string) {
    this.testingUrl = givenUrl;

    // ignore requirement of angular-based applications (for non-angular-based applications)
    browser.ignoreSynchronization = true;
  }

  // functions
  public getBrowser() {
    return browser;
  }

  public navigateTo() {
    browser.get(this.testingUrl);
  }

  public getTitle() {
    return browser.getTitle();
  }
}

export class E2ETesting extends BaseOfE2ETesing {
  //
  constructor(givenUrl: string) {
    super(givenUrl);
  }
}

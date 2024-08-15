import { createElement } from 'lwc';
import RpBusinessSearch from 'c/rpBusinessSearch';

describe('c-rp-business-search', () => {
  afterEach(() => {
    // The jsdom instance is shared across test cases in a single file so reset the DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it('TODO: test case generated by CLI command, please fill in test logic', () => {
    // Arrange
    const element = createElement('c-rp-business-search', {
      is: RpBusinessSearch,
    });

    // Act
    document.body.appendChild(element);

    // Assert
    // const div = element.shadowRoot.querySelector('div');
    expect(1).toBe(1);
  });
});

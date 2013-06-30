/*
 * Function Object: Object1
 *
 * The first function object.
 */

// Group: Constructors

/*
 * Constructor: Object1
 *
 * The constructor.
 */
function Object1() {
}

// Group: Properties

/*
 * Property: property1
 *
 * The first property.
 */
Object1.property1 = 1;

/*
 * Property: property2
 *
 * The second property.
 */
Object1.prototype.property2 = 2;

// Group: Methods

/*
 * Method: method1
 *
 * The first method.
 */
Object1.method1 = function () {};

/*
 * Method: method2
 *
 * The second method.
 */
Object1.prototype.method2 = function () {};

/*
 * Function Object: Object2
 *
 * The second function object.
 */

// Group: Constructors

/*
 * Constructor: Object2
 *
 * The constructor.
 */
function Object2() {
}

Object2.prototype = {
    constructor: Object2,
    // Group: Properties
    /*
     * Property: property21
     *
     * The first property od the second object.
     */
    property21: 21,
    // Group: Methods
    /*
     * Method: method21
     *
     * The first method od the second object.
     */
    method21: function () {}
};

-- Java TestNG Snippets

local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local fmt = require("luasnip.extras.fmt").fmt

-- Get current date in "Month Day, Year" format
local function get_current_date()
  return os.date("%B %d, %Y")
end

-- Get current class name from file name
local function get_class_name()
  local file_name = vim.fn.expand("%:t")
  return file_name:match("(.+)%.java$") or ""
end

-- TestNG Snippets
return {
  -- TestNG Test Method
  s("tngtest", fmt([[
  @Test
  public void {}() {{
      {}
  }}
  ]], {
    i(1, "testMethod"),
    i(2, "// Test implementation")
  })),

  -- TestNG Test Method with Description
  s("tngdesc", fmt([[
  @Test(description = "{}")
  public void {}() {{
      {}
  }}
  ]], {
    i(1, "Test description"),
    i(2, "testMethod"),
    i(3, "// Test implementation")
  })),

  -- TestNG Test Method with Groups
  s("tnggroup", fmt([[
  @Test(groups = {{ "{}" }})
  public void {}() {{
      {}
  }}
  ]], {
    i(1, "group-name"),
    i(2, "testMethod"),
    i(3, "// Test implementation")
  })),

  -- TestNG Data Provider
  s("tngdp", fmt([[
  @DataProvider(name = "{}")
  public Object[][] {}() {{
      return new Object[][] {{
          {{ {} }},
          {{ {} }}
      }};
  }}
  ]], {
    i(1, "dataProviderName"),
    i(2, "provideData"),
    i(3, "value1, value2"),
    i(4, "value3, value4")
  })),

  -- TestNG Test with Data Provider
  s("tngdptest", fmt([[
  @Test(dataProvider = "{}")
  public void {}({}) {{
      {}
  }}
  ]], {
    i(1, "dataProviderName"),
    i(2, "testMethod"),
    i(3, "String param1, String param2"),
    i(4, "// Test implementation using parameters")
  })),

  -- TestNG BeforeMethod
  s("tngbm", fmt([[
  @BeforeMethod
  public void {}() {{
      {}
  }}
  ]], {
    i(1, "setUp"),
    i(2, "// Setup code")
  })),

  -- TestNG AfterMethod
  s("tngam", fmt([[
  @AfterMethod
  public void {}() {{
      {}
  }}
  ]], {
    i(1, "tearDown"),
    i(2, "// Teardown code")
  })),

  -- TestNG BeforeClass
  s("tngbc", fmt([[
  @BeforeClass
  public void {}() {{
      {}
  }}
  ]], {
    i(1, "setUpClass"),
    i(2, "// Class setup code")
  })),

  -- TestNG AfterClass
  s("tngac", fmt([[
  @AfterClass
  public void {}() {{
      {}
  }}
  ]], {
    i(1, "tearDownClass"),
    i(2, "// Class teardown code")
  })),

  -- TestNG Expected Exception
  s("tngex", fmt([[
  @Test(expectedExceptions = {}.class)
  public void {}() {{
      {}
  }}
  ]], {
    i(1, "Exception"),
    i(2, "testExceptionThrown"),
    i(3, "// Code that should throw exception")
  })),

  -- TestNG Assertion - assertEquals
  s("tngaeq", fmt([[
  assertEquals({}, {}, "{}");
  ]], {
    i(1, "actual"),
    i(2, "expected"),
    i(3, "Values should be equal")
  })),

  -- TestNG Assertion - assertTrue
  s("tngat", fmt([[
  assertTrue({}, "{}");
  ]], {
    i(1, "condition"),
    i(2, "Condition should be true")
  })),

  -- TestNG Assertion - assertFalse
  s("tngaf", fmt([[
  assertFalse({}, "{}");
  ]], {
    i(1, "condition"),
    i(2, "Condition should be false")
  })),

  -- TestNG Assertion - assertNotNull
  s("tngannn", fmt([[
  assertNotNull({}, "{}");
  ]], {
    i(1, "object"),
    i(2, "Object should not be null")
  })),

  -- TestNG Assertion - assertNull
  s("tngan", fmt([[
  assertNull({}, "{}");
  ]], {
    i(1, "object"),
    i(2, "Object should be null")
  })),

  -- Complete TestNG Test Class Template
  s("tngclass", fmt([[
/**
 * TestNG Test class for {}
 * 
 * @author {}
 * @since {}
 */
public class {} extends {} {{

    /**
     * Set up before each test method
     */
    @BeforeMethod
    public void setUp() {{
        {}
    }}

    /**
     * Clean up after each test method
     */
    @AfterMethod
    public void tearDown() {{
        {}
    }}

    /**
     * Test method for basic functionality
     */
    @Test
    public void testBasicFunctionality() {{
        {}
    }}

    /**
     * Test method with parameters from data provider
     */
    @Test(dataProvider = "testDataProvider")
    public void testWithParameters({}) {{
        {}
    }}

    /**
     * Data provider for parameterized tests
     */
    @DataProvider(name = "testDataProvider")
    public Object[][] provideTestData() {{
        return new Object[][] {{
            {{ {} }},
            {{ {} }}
        }};
    }}
}}
  ]], {
    i(1, "SomeClass"),
    i(2, "Your Name"),
    f(function() return os.date("%B %d, %Y") end),
    c(3, {
      i(1, get_class_name()),
      i(2, "TestClassName")
    }),
    c(4, {
      i(1, "TestCase"),
      i(2, "BaseTest"),
      i(3, "Object")
    }),
    i(5, "// Initialize test objects"),
    i(6, "// Clean up resources"),
    i(7, "// Test implementation"),
    i(8, "String param1, String param2"),
    i(9, "// Test with parameters"),
    i(10, "\"value1\", \"value2\""),
    i(11, "\"value3\", \"value4\"")
  })),
}
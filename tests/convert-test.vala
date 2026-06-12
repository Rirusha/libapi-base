/*
 * Copyright (C) 2026 Vladimir Romanov <rirusha@altlinux.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see
 * <https://www.gnu.org/licenses/gpl-3.0-standalone.html>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

// ind-check=skip-file
// vala-lint=skip-file

using Serialize;

const string TEST_JSON = """{"name":"test","value":"42","active":"yes","items":["a","b","c"]}""";

public int main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/convert/json-to-yaml", () => {
        try {
            var result = Convert.convert_data (
                TEST_JSON,
                ConvertableDataType.JSON,
                ConvertableDataType.YAML
            );

            //  YAML should contain the keys
            if (!result.contains ("name:")) {
                Test.fail_printf ("YAML missing 'name' key");
            }
            if (!result.contains ("value:")) {
                Test.fail_printf ("YAML missing 'value' key");
            }
            if (!result.contains ("active:")) {
                Test.fail_printf ("YAML missing 'active' key");
            }
            if (!result.contains ("items:")) {
                Test.fail_printf ("YAML missing 'items' key");
            }

        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/convert/yaml-to-json", () => {
        try {
            var yaml = """name: test
value: 42
items:
  - a
  - b
  - c
""";

            var result = Convert.convert_data (
                yaml,
                ConvertableDataType.YAML,
                ConvertableDataType.JSON
            );

            //  JSON should contain the keys and values
            if (!result.contains ("\"name\"")) {
                Test.fail_printf ("JSON missing 'name'");
            }
            if (!result.contains ("\"value\"")) {
                Test.fail_printf ("JSON missing 'value'");
            }
            if (!result.contains ("\"items\"")) {
                Test.fail_printf ("JSON missing 'items'");
            }

        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/convert/json-to-json", () => {
        try {
            var result = Convert.convert_data (
                TEST_JSON,
                ConvertableDataType.JSON,
                ConvertableDataType.JSON
            );

            //  Roundtrip should preserve structure
            var worker = new JsonWorker (result);
            var dict = worker.deserialize ();

            if (dict["name"].get_string () != "test") {
                Test.fail_printf ("name mismatch");
            }
            if (dict["value"].get_string () != "42") {
                Test.fail_printf ("value mismatch");
            }

        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/convert/yaml-to-yaml", () => {
        try {
            var yaml = """name: test
value: 42
""";

            var result = Convert.convert_data (
                yaml,
                ConvertableDataType.YAML,
                ConvertableDataType.YAML
            );

            //  Roundtrip should preserve structure
            if (!result.contains ("name:")) {
                Test.fail_printf ("YAML missing 'name'");
            }
            if (!result.contains ("value:")) {
                Test.fail_printf ("YAML missing 'value'");
            }

        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/convert/json-to-yaml/null", () => {
        try {
            var json = "{\"name\":null,\"value\":42}";

            var result = Convert.convert_data (
                json,
                ConvertableDataType.JSON,
                ConvertableDataType.YAML
            );

            //  YAML should contain null representation
            if (!result.contains ("name:")) {
                Test.fail_printf ("YAML missing 'name'");
            }

        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    Test.add_func ("/convert/yaml-to-json/null", () => {
        try {
            var yaml = """name: null
value: 42
""";

            var result = Convert.convert_data (
                yaml,
                ConvertableDataType.YAML,
                ConvertableDataType.JSON
            );

            //  JSON should contain null
            if (!result.contains ("\"name\":null")) {
                Test.fail_printf ("JSON missing 'name':null");
            }

        } catch (Serialize.Error e) {
            Test.fail_printf (e.domain.to_string () + ": " + e.message);
        }
    });

    return Test.run ();
}
